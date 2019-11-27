package main

import (
	"fmt"
	"log"
	"sort"
	"strings"

	"github.com/gocolly/colly"
)

func main() {
	c := colly.NewCollector()
	var versions []string
	c.OnHTML(`div.commit .commit-title a`, func(e *colly.HTMLElement) {
		if versionString := e.Attr("href"); !strings.Contains(versionString, "-rc") {
			versions = append(versions, versionString)
		}
	})
	c.Visit("https://github.com/git/git/tags")
	sort.Strings(versions)
	if len(versions) == 0 {
		log.Fatalln("no versions were found when scraping github")
	}
	fmt.Println(versions[len(versions)-1])
}
