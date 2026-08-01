local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
	-- Frontmatter (Obsidian YAML)
	s("fm", {
		t({ "---", "title: " }),
		i(1, "Title"),
		t({ "", "date: " }),
		f(function()
			return os.date("%Y-%m-%d")
		end),
		t({ "", "tags: [" }),
		i(2),
		t({ "]", "---", "", "" }),
		i(0),
	}),

	-- Callouts (Obsidian style)
	s("note", { t("> [!note] "), i(1, "Title"), t({ "", "> " }), i(0) }),
	s("warn", { t("> [!warning] "), i(1, "Title"), t({ "", "> " }), i(0) }),
	s("tip", { t("> [!tip] "), i(1, "Title"), t({ "", "> " }), i(0) }),
	s("info", { t("> [!info] "), i(1, "Title"), t({ "", "> " }), i(0) }),
	s("todo", { t("> [!todo] "), i(1, "Title"), t({ "", "> " }), i(0) }),

	-- Links
	s("wl", { t("[["), i(1), t("]]") }), -- wiki link
	s("wla", { t("[["), i(1), t("|"), i(2), t("]]") }), -- wiki link with alias
	s("link", { t("["), i(1, "text"), t("]("), i(2, "url"), t(")") }),

	-- Code blocks
	s("cb", { t("```"), i(1, "lang"), t({ "", "" }), i(2), t({ "", "```" }) }),

	-- Task / checkbox
	s("td", { t("- [ ] "), i(0) }),

	-- Table (2x2)
	s("tbl", {
		t({ "| " }),
		i(1, "Header 1"),
		t(" | "),
		i(2, "Header 2"),
		t({ " |", "| --- | --- |", "| " }),
		i(3),
		t(" | "),
		i(4),
		t({ " |" }),
	}),

	-- Heading shortcuts
	s("h1", { t("# "), i(0) }),
	s("h2", { t("## "), i(0) }),
	s("h3", { t("### "), i(0) }),
	s("h4", { t("#### "), i(0) }),

	-- Daily note template
	s("daily", {
		t({ "---", "title: Daily Note - " }),
		f(function()
			return os.date("%Y-%m-%d")
		end),
		t({ "", "date: " }),
		f(function()
			return os.date("%Y-%m-%d")
		end),
		t({ "", "tags: [daily]", "---", "", "## Tasks", "", "- [ ] " }),
		i(1),
		t({ "", "", "## Notes", "", "" }),
		i(0),
	}),
}

