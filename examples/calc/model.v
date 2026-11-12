// Calculator state and a small recursive-descent arithmetic parser.
module calc

import math
import strconv

pub struct Model {
pub mut:
	expression string
	message    string
	evaluated  bool
}

pub fn (m &Model) display() string { return if m.expression == '' { '0' } else { m.expression } }

fn operator(c u8) bool { return c in [`+`, `-`, `*`, `/`] }

// Locate the final number or balanced group, including postfix operators and sign.
fn operand_start(s string) int {
	mut end := s.len
	for end > 0 {
		if s[..end].ends_with('^2') {
			end -= 2
		} else if s[end - 1] == `%` {
			end--
		} else {
			break
		}
	}
	if end == 0 { return s.len }
	mut start := end
	if s[end - 1] == `)` {
		mut depth := 1
		start = end - 1
		for start > 0 && depth > 0 {
			start--
			if s[start] == `)` { depth++ }
			if s[start] == `(` { depth-- }
		}
		if depth != 0 { return s.len }
	} else {
		for start > 0 {
			c := s[start - 1]
			if c.is_digit() || c in [`.`, `e`, `E`] {
				start--
				continue
			}
			if c in [`+`, `-`] && start >= 2 && s[start - 2] in [`e`, `E`] {
				start--
				continue
			}
			break
		}
	}
	if start == end { return s.len }
	if start > 0 && s[start - 1] == `-` && (start == 1 || operator(s[start - 2]) || s[start - 2] == `(`) {
		start--
	}
	return start
}

pub fn (mut m Model) press(key string) {
	m.message = ''
	match key {
		'C' {
			m.expression = ''
			m.evaluated = false
		}
		'CE' {
			start := operand_start(m.expression)
			m.expression = m.expression[..start]
			m.evaluated = false
		}
		'<' {
			if m.expression.ends_with('^2') {
				m.expression = m.expression[..m.expression.len - 2]
			} else if m.expression.len > 0 {
				m.expression = m.expression[..m.expression.len - 1]
			}
			m.evaluated = false
		}
		'+-' {
			if m.expression == '' {
				m.expression = '-'
				return
			}
			start := operand_start(m.expression)
			if start == m.expression.len {
				m.expression += '-'
				return
			}
			operand := m.expression[start..]
			m.expression = m.expression[..start] + if operand.starts_with('-') {
				operand[1..]
			} else {
				'-' + operand
			}
			m.evaluated = false
		}
		'=' {
			value := evaluate(m.expression) or {
				m.message = err.msg()
				return
			}
			m.expression = if value == 0 { '0' } else { '${value:.12g}' }
			m.evaluated = true
		}
		'%', 'x2' {
			if operand_start(m.expression) == m.expression.len { return }
			// Parenthesize the signed operand so (-3)^2 yields +9.
			start := operand_start(m.expression)
			operand := m.expression[start..]
			m.expression = m.expression[..start] + '(' + operand + ')' + if key == '%' {
				'%'
			} else {
				'^2'
			}
			m.evaluated = false
		}
		else {
			mut input := if key == 'x' { '*' } else { key }
			if input.len != 1 || !(input[0].is_digit() || input[0] in [`.`, `+`, `-`, `*`, `/`,
				`(`, `)`]) {
				return
			}
			if m.evaluated && (input[0].is_digit() || input in ['.', '(']) { m.expression = '' }
			m.evaluated = false
			if m.expression.len >= 160 {
				m.message = 'Expression too long'
				return
			}
			if input == '.' {
				start := operand_start(m.expression)
				if start < m.expression.len && m.expression[start..].contains('.') { return }
				if m.expression == '' || operator(m.expression[m.expression.len - 1]) || m.expression.ends_with('(') {
					input = '0.'
				}
			}
			m.expression += input
		}
	}
}

struct Parser {
	text string
mut:
	position int
}

pub fn evaluate(text string) !f64 {
	if text.len == 0 { return error('Enter an expression') }
	if text.len > 200 { return error('Expression too long') }
	mut p := Parser{ text: text }
	value := p.sum()!
	if p.position != text.len { return error('Check operators and parentheses') }
	if math.is_nan(value) || math.is_inf(value, 0) { return error('Result is out of range') }
	return value
}

fn (mut p Parser) sum() !f64 {
	mut value := p.product()!
	for p.position < p.text.len && p.text[p.position] in [`+`, `-`] {
		op := p.text[p.position]
		p.position++
		rhs := p.product()!
		value = if op == `+` { value + rhs } else { value - rhs }
	}
	return value
}

fn (mut p Parser) product() !f64 {
	mut value := p.unary()!
	for p.position < p.text.len && p.text[p.position] in [`*`, `/`] {
		op := p.text[p.position]
		p.position++
		rhs := p.unary()!
		if op == `/` && rhs == 0 { return error('Cannot divide by zero') }
		value = if op == `*` { value * rhs } else { value / rhs }
	}
	return value
}

fn (mut p Parser) unary() !f64 {
	if p.position < p.text.len && p.text[p.position] in [`+`, `-`] {
		op := p.text[p.position]
		p.position++
		value := p.unary()!
		return if op == `-` { -value } else { value }
	}
	return p.postfix()
}

fn (mut p Parser) postfix() !f64 {
	mut value := p.primary()!
	for p.position < p.text.len {
		if p.text[p.position] == `%` {
			value /= 100
			p.position++
		} else if p.text[p.position..].starts_with('^2') {
			value *= value
			p.position += 2
		} else {
			break
		}
	}
	return value
}

fn (mut p Parser) primary() !f64 {
	if p.position >= p.text.len { return error('Finish the expression') }
	if p.text[p.position] == `(` {
		p.position++
		value := p.sum()!
		if p.position >= p.text.len || p.text[p.position] != `)` {
			return error('Close the parentheses')
		}
		p.position++
		return value
	}
	start := p.position
	mut dot := false
	mut digits := 0
	for p.position < p.text.len {
		ch := p.text[p.position]
		if ch.is_digit() {
			digits++
			p.position++
			continue
		}
		if ch == `.` && !dot {
			dot = true
			p.position++
			continue
		}
		break
	}
	if digits == 0 { return error('Expected a number') }
	if p.position < p.text.len && p.text[p.position] in [`e`, `E`] {
		p.position++
		if p.position < p.text.len && p.text[p.position] in [`+`, `-`] { p.position++ }
		exponent := p.position
		for p.position < p.text.len && p.text[p.position].is_digit() { p.position++ }
		if exponent == p.position { return error('Invalid exponent') }
	}
	return strconv.atof64(p.text[start..p.position])
}
