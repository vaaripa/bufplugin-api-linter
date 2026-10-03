package main

import (
	"context"
	"fmt"
	"log"
	"strings"

	"buf.build/go/bufplugin/check"
	"buf.build/go/bufplugin/check/checkutil"
	"buf.build/go/bufplugin/descriptor"
	"buf.build/go/bufplugin/info"
	"github.com/googleapis/api-linter/v2/lint"
	"github.com/googleapis/api-linter/v2/rules"
)

const allCategory = "AIP_ALL"

func main() {
	spec, err := buildSpec()
	if err != nil {
		log.Fatalf("failed to build buf plugin spec: %v", err)
	}

	check.Main(spec)
}

func buildSpec() (*check.Spec, error) {
	aipRules, err := getAIPRules()
	if err != nil {
		return nil, fmt.Errorf("failed to get AIP lint rules: %w", err)
	}

	var rules []*check.RuleSpec
	for ruleName, aipRule := range aipRules {
		rules = append(rules, aipRuleToBufRule(ruleName, aipRule))
	}

	return &check.Spec{
		Rules: rules,
		Categories: []*check.CategorySpec{
			{ID: allCategory, Purpose: "Checks all Google api-linter rules."},
		},
		Info: &info.Spec{
			Documentation: "A linting plugin that checks Google AIP conformance via the api-linter project",
		},
	}, nil
}

func aipRuleNameToBufID(name lint.RuleName) string {
	replacer := strings.NewReplacer("::", "_", "-", "_")
	return "AIP_" + strings.ToUpper(replacer.Replace(string(name)))
}

func aipRuleToBufRule(ruleName lint.RuleName, rule lint.ProtoRule) *check.RuleSpec {
	linter := lint.New(map[lint.RuleName]lint.ProtoRule{ruleName: rule}, lint.Configs{})

	handler := func(ctx context.Context, writer check.ResponseWriter, request check.Request, descriptor descriptor.FileDescriptor) error {
		res, err := linter.LintProtos(descriptor.ProtoreflectFileDescriptor())
		if err != nil {
			return fmt.Errorf("failed to lint protos: %w", err)
		}

		for _, r := range res {
			for _, problem := range r.Problems {
				writer.AddAnnotation(
					check.WithMessage(fmt.Sprintf("%s See %s", problem.Message, problem.GetRuleURI())),
					check.WithDescriptor(problem.Descriptor),
				)
			}
		}

		return nil
	}

	return &check.RuleSpec{
		ID:          aipRuleNameToBufID(rule.GetName()),
		CategoryIDs: []string{allCategory},
		Type:        check.RuleTypeLint,
		Purpose:     fmt.Sprintf("Validates Google AIP %s.", rule.GetName()),
		Default:     true,
		Handler:     checkutil.NewFileRuleHandler(handler, checkutil.WithoutImports()),
	}
}

func getAIPRules() (map[lint.RuleName]lint.ProtoRule, error) {
	r := make(map[lint.RuleName]lint.ProtoRule)
	if err := rules.Add(r); err != nil {
		return nil, err
	}
	return r, nil
}
