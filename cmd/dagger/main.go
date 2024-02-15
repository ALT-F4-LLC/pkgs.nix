package main

import (
	"context"
	"fmt"
	"os"

	"dagger.io/dagger"
)

func build(ctx context.Context) error {
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(os.Stderr))
	if err != nil {
		return err
	}

	defer client.Close()

	container := client.
		Container().
		From("nixpkgs/cachix-flakes:latest").
		WithDirectory("/app", client.Host().Directory("."))

	setupExecs := [][]string{
		{"mkdir", "-p", "/usr/src/app"},
		{"cp", "-a", "/app/.", "/usr/src/app/"},
		{"rm", "-rf", "/usr/src/app/.git"},
	}

	for _, cmd := range setupExecs {
		container = container.WithExec(cmd)
	}

	container = container.WithWorkdir("/usr/src/app")

	buildExecs := [][]string{
		{"nix", "build", "--json", "--no-link", "--option", "filter-syscalls", "false", "--print-build-logs", ".#dagger"},
	}

	for _, cmd := range buildExecs {
		container = container.WithExec(cmd)
	}

	_, errExport := container.Stdout(ctx)
	if errExport != nil {
		panic(errExport)
	}

	return nil
}

func main() {
	if err := build(context.Background()); err != nil {
		fmt.Println(err)
	}
}
