package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/marcelsud/sdl-cli/internal/sdl"
)

var validateCmd = &cobra.Command{
	Use:   "validate [path]",
	Short: "Validate SDL files against the spec",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		path := "."
		if len(args) == 1 {
			path = args[0]
		}

		files, err := sdl.FindSDLFiles(path)
		if err != nil {
			return err
		}
		if len(files) == 0 {
			return fmt.Errorf("no .sdl files found under %s", path)
		}

		problems, err := sdl.ValidatePaths(files)
		if err != nil {
			return err
		}

		errors := 0
		warnings := 0
		for _, p := range problems {
			fmt.Fprintln(cmd.ErrOrStderr(), p.Error())
			if p.Severity == "warning" {
				warnings++
			} else {
				errors++
			}
		}

		if errors > 0 {
			return exitError{code: 1, err: fmt.Errorf("validation failed (%d errors, %d warnings)", errors, warnings)}
		}

		msg := fmt.Sprintf("%d file(s) valid", len(files))
		if warnings > 0 {
			msg = fmt.Sprintf("%s (%d warning(s))", msg, warnings)
		}
		fmt.Fprintln(cmd.OutOrStdout(), msg)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(validateCmd)
}
