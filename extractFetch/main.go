package main

import (
	"flag"
	"fmt"
	"os"
	"regexp"
	"strings"
	"unicode"

	"github.com/gocolly/colly"
)

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func parseFlags() *string {
	jslist := flag.String("w", "", "Javascript files")

	flag.Parse()

	return jslist
}

var filesThatFetch []string

func main() {

	jsFileWithFetch()
	fmt.Println(filesThatFetch)
}

func extractjs() {
	urlsToExtract := []string{
		"https://in.goibibo.com/newextranet/login",
	}

	c := colly.NewCollector(colly.AllowedDomains("jsak.mmtcdn.com", "in.goibibo.com"))

	c.OnHTML("script", func(e *colly.HTMLElement) {
		src := e.Attr("src")
		if src != "" {
			fmt.Println("Script src:", src)
		} else {
			content := e.Text
			fmt.Println("Inline script content:\n", content)
		}
	})

	// Visit each URL
	for _, url := range urlsToExtract {
		c.Visit(url)
	}
}

func jsFileWithFetch() {
	javscriptFiles := parseFlags()

	f := func(c rune) bool {
		return unicode.IsSpace(c)
	}

	fileNames := strings.FieldsFunc(*javscriptFiles, f)
	fmt.Println(fileNames)
	extractByFileContent(fileNames)

}

func extractByFileContent(fileNames []string) {

	patterns := []string{
		`\bfetch\s*\(([^)]+)\)`,
		`\baxios\.(get|post|put|delete)\s*\(([^)]+)\)`,
		`\bXMLHttpRequest\b`,
		`\$\.ajax\s*\(([^)]+)\)`,
		`url\s*:\s*['"]([^'"]+)['"]`,
		`method\s*:\s*['"](GET|POST|PUT|DELETE)['"]`,
		`headers\s*:\s*\{[^}]+\}`,
	}
	for _, fileName := range fileNames {
		fileData, err := os.ReadFile(fileName)
		check(err)
		for _, pattern := range patterns {
			isFecthing, err := regexp.Match(pattern, fileData)
			check(err)
			if isFecthing {
				filesThatFetch = append(filesThatFetch, fileName)
			}
		}
	}

}

// I'm doing an authorized security assesment on a web application. Analyze the provided JavaScript code to identify and document all API endpoints, methos, parameters, headers, and authorization requirements.
// The JavaScript file likely includes AJAX calls, fetch request, or similar API interactions. Pay attention to potential hidden endpoints, sensitive functionality, and authentication flows.

// For Each identified endpoint:

// - Clearly document the endpoint URL and HTTP method.
// - List required parameters and example/sample values.
// - Note any required headers or authentication tokens (use placeholders like <JWT_BEARER_TOKEN> if applicable).
// - Generate ready to use curl commands.
// - Highlight potential security concerns you notice in endpoint implementation (such as insecure authentication practice or overly permissive endpoints).

// The output should be in markdown and it provides actionable reconnaissance data that directly supports further security testing and clearly highlights immediate security concerns.
