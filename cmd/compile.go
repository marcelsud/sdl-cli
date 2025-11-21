package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var compileCmd = &cobra.Command{
	Use:   "compile [path]",
	Short: "Compile SDL packages (stub)",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		path := "."
		if len(args) == 1 {
			path = args[0]
		}
		_ = path
		fmt.Fprintln(cmd.OutOrStdout(), "compile is not implemented yet")
		return nil
	},
}

func init() {
	rootCmd.AddCommand(compileCmd)
}
