class Template {
	// Super simple template engine for Beat
	// Stolen from mde/ejs
	// http://ejs.co

	constructor (html) {
		this.templateData = this.parse(html)
		this.compiled = this.compile(this.templateData)
	}

	withData = (data) => {
		return this.compiled(data)
	}

	parse = (template) => {
		let result = /{{(.*?)}}/g.exec(template);
		const arr = [];
		let firstPos;

		while (result) {
			firstPos = result.index;
			if (firstPos !== 0) {
				arr.push(template.substring(0, firstPos));
				template = template.slice(firstPos);
			}

			arr.push(result[0]);
			template = template.slice(result[0].length);
			result = /{{(.*?)}}/g.exec(template);
		}

		if (template) arr.push(template);
		return arr;
	}

	compile = (template) => {
		return new Function("data", "return " + this.compileToString(template))
	}

	compileToString = (template) => {
		const ast = template;
		let fnStr = `""`;

		ast.map(t => {
			// checking to see if it is an interpolation
			if (t.startsWith("{{") && t.endsWith("}}")) {
				// append it to fnStr
				fnStr += `+data.${t.split(/{{|}}/).filter(Boolean)[0].trim()}`;
			} else {
				// append the string to the fnStr
				fnStr += `+"${t}"`;
			}
		});

		return fnStr;
	}

}
