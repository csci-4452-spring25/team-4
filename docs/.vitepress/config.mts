import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
	title: "Cloud Showcase",
	description: "By Kenneth",
	base: "/team-4/",
	themeConfig: {
		// https://vitepress.dev/reference/default-theme-config
		nav: [
			{ text: "Home", link: "/" },
			{ text: "Introduction", link: "/overview" },
			{ text: "Goals", link: "/goals" },
			{ text: "Process", link: "/process" },
			{ text: "Challenges", link: "/challenges" },
			{ text: "Conclusion", link: "/conclusion" },
			{ text: "Snippets", link: "/examples" },
		],

		sidebar: [
			{
				text: "Documentation",
				items: [
					{ text: "Introduction", link: "/overview" },
					{ text: "Goals Accomplished", link: "/goals" },
					{ text: "Summary of the Process", link: "/process" },
					{ text: "Challenges Encountered", link: "/challenges" },
					{ text: "Conclusion", link: "/conclusion" },
				],
			},
			{
				text: "Snippets",
				link: "/examples",
			},
		],

		socialLinks: [{ icon: "github", link: "https://github.com/vuejs/vitepress" }],
	},
});
