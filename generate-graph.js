const fs = require('fs');

if (!fs.existsSync('scanner-report.json')) {
    console.error('scanner-report.json not found!');
    process.exit(1);
}

const data = JSON.parse(fs.readFileSync('scanner-report.json', 'utf8'));

let nodes = new Set();
let edges = [];

data.forEach(issue => {
    const file = issue.fileName || "unknown-file";
    const rule = issue.ruleName || "unknown-rule";

    nodes.add(file);
    nodes.add(rule);

    edges.push(`"${file}" -> "${rule}"`);
});

let dot = `
digraph G {
    rankdir=LR;
    node [shape=box];

    ${[...nodes].map(n => `"${n}"`).join('\n')}
    
    ${edges.join('\n')}
}
`;

fs.writeFileSync('graph.dot', dot);

console.log("graph.dot generated successfully");