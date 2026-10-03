package main

import (
	"testing"

	"buf.build/go/bufplugin/check/checktest"
)

func TestBuildSpec(t *testing.T) {
	spec, err := buildSpec()
	if err != nil {
		t.Fatal(err)
	}

	checktest.CheckTest{
		Request: &checktest.RequestSpec{
			Files: &checktest.ProtoFileSpec{
				DirPaths:  []string{"testdata"},
				FilePaths: []string{"test.proto"},
			},
		},
		Spec: spec,
		ExpectedAnnotations: []checktest.ExpectedAnnotation{
			{
				RuleID:  "AIP_CORE_0192_HAS_COMMENTS",
				Message: `Missing comment over "Book".`,
				FileLocation: &checktest.ExpectedFileLocation{
					FileName:    "test.proto",
					StartLine:   2,
					StartColumn: 0,
					EndLine:     2,
					EndColumn:   15,
				},
			},
		},
	}.Run(t)
}
