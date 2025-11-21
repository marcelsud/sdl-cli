package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/marcelsud/sdl-cli/internal/sdl"
)

var (
	fmtCheck       bool
	fmtDiff        bool
	fmtWrite       bool
	fmtActionStyle string
	fmtLineLength  int
)

var fmtCmd = &cobra.Command{
	Use:   "fmt [path]",
	Short: "Format SDL files (like terraform fmt)",
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

		if fmtActionStyle == "" {
			fmtActionStyle = "auto"
		}
		if fmtActionStyle != "single" && fmtActionStyle != "multi" && fmtActionStyle != "auto" {
			return fmt.Errorf("invalid --actions value: %s (expected single|multi|auto)", fmtActionStyle)
		}

		opts := sdl.FormatOptions{
			Write:           fmtWrite,
			Check:           fmtCheck,
			Diff:            fmtDiff,
			ActionStyle:     fmtActionStyle,
			ActionLineLimit: fmtLineLength,
		}
		if fmtDiff {
			opts.Write = false
		}

		results, err := sdl.FormatFiles(files, opts)
		if err != nil {
			return err
		}

		changed := 0
		for _, res := range results {
			if !res.Changed {
				continue
			}
			changed++
			if fmtDiff && res.Diff != "" {
				fmt.Fprint(cmd.OutOrStdout(), res.Diff)
			} else if fmtCheck {
				fmt.Fprintln(cmd.OutOrStdout(), res.Path)
			}
		}

		if fmtCheck && changed > 0 {
			return exitError{code: 3, err: fmt.Errorf("%d file(s) would be reformatted", changed)}
		}
		return nil
	},
}

func init() {
	fmtCmd.Flags().BoolVar(&fmtCheck, "check", false, "check if files are formatted without writing")
	fmtCmd.Flags().BoolVar(&fmtDiff, "diff", false, "show diff of formatting changes (implies --write=false)")
	fmtCmd.Flags().BoolVar(&fmtWrite, "write", true, "write changes to files (default true)")
	fmtCmd.Flags().StringVar(&fmtActionStyle, "actions", "auto", "action layout: single, multi, or auto (breaks lines when longer than limit)")
	fmtCmd.Flags().IntVar(&fmtLineLength, "line-length", 100, "line length limit for --actions=auto (0 to disable)")
	rootCmd.AddCommand(fmtCmd)
}
