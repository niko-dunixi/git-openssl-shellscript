package main

import (
	"fmt"
	"log"
	"os"
	"sort"
	"strings"

	"github.com/gocolly/colly"
)

func main() {
	c := colly.NewCollector()
	var versions []string
	c.OnHTML(`div.commit a.muted-link`, func(e *colly.HTMLElement) {
		href := e.Attr("href")
		debug("found href: %s", href)
		if strings.HasSuffix(href, ".tar.gz") {
			debug("saving: %s", href)
			versions = append(versions, href)
		}
	})
	c.Visit("https://github.com/git/git/tags")
	sort.Strings(versions)
	debug("sorted versions: %v", versions)
	if len(versions) == 0 {
		log.Fatalln("no versions were found when scraping github")
	}
	fmt.Printf("https://www.github.com%s", versions[len(versions)-1])
}

func debug(s string, args ...interface{}) {
	if debug := os.Getenv("DEBUG"); debug != "" {
		log.Printf(s, args...)
	}
}
