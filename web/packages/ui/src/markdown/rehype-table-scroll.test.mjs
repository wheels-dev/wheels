import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { rehypeTableScroll } from './rehype-table-scroll.mjs';

// Minimal hast helpers — no dependencies.
const el = (tagName, children = [], properties = {}) => ({ type: 'element', tagName, properties, children });
const text = (value) => ({ type: 'text', value });
const root = (...children) => ({ type: 'root', children });

const run = (tree) => {
	rehypeTableScroll()(tree);
	return tree;
};

test('wraps a top-level table and sets the accessible wrapper properties', () => {
	const tree = run(root(el('table')));
	assert.equal(tree.children.length, 1);
	const wrapper = tree.children[0];
	assert.equal(wrapper.type, 'element');
	assert.equal(wrapper.tagName, 'div');
	assert.deepEqual(wrapper.properties.className, ['table-scroll']);
	assert.equal(wrapper.properties.role, 'region');
	assert.equal(wrapper.properties.ariaLabel, 'Table');
	assert.equal(wrapper.properties.tabIndex, 0);
	assert.equal(wrapper.children.length, 1);
	assert.equal(wrapper.children[0].tagName, 'table');
});

test('wraps a table nested inside another element', () => {
	const tree = run(root(el('div', [el('table')])));
	const outer = tree.children[0];
	assert.equal(outer.tagName, 'div');
	const wrapper = outer.children[0];
	assert.equal(wrapper.tagName, 'div');
	assert.deepEqual(wrapper.properties.className, ['table-scroll']);
	assert.equal(wrapper.children[0].tagName, 'table');
});

test('leaves non-table siblings alone', () => {
	const paragraph = el('p', [text('hello')]);
	const tree = run(root(paragraph, el('table')));
	assert.equal(tree.children[0], paragraph);
	assert.equal(tree.children[0].tagName, 'p');
	assert.equal(tree.children[1].tagName, 'div');
	assert.equal(tree.children[1].children[0].tagName, 'table');
});

test('does not double-wrap a table already inside div.table-scroll', () => {
	const table = el('table');
	const existing = el('div', [table], { className: ['table-scroll'] });
	const tree = run(root(existing));
	assert.equal(tree.children.length, 1);
	assert.equal(tree.children[0], existing);
	assert.equal(tree.children[0].children.length, 1);
	assert.equal(tree.children[0].children[0], table);
});

test('wraps each of multiple tables in its own wrapper', () => {
	const tree = run(root(el('table'), el('table')));
	assert.equal(tree.children.length, 2);
	assert.notEqual(tree.children[0], tree.children[1]);
	assert.equal(tree.children[0].children[0].tagName, 'table');
	assert.equal(tree.children[1].children[0].tagName, 'table');
	assert.notEqual(tree.children[0].children[0], tree.children[1].children[0]);
});
