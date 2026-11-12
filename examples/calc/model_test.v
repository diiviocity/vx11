module calc

fn test_arithmetic() {
	assert evaluate('2+3*4')! == 14
	assert evaluate('(2+3)*4')! == 20
	assert evaluate('-3+(-2)')! == -5
	assert evaluate('200*10%')! == 20
	assert evaluate('(-3)^2')! == 9
	assert evaluate('1e-5*1e5')! == 1
	for text in ['1/0', '(2+3', '2..3', '2(3)', '3+', ''] {
		mut failed := false
		evaluate(text) or { failed = true }
		assert failed
	}
}

fn test_editing_and_results() {
	mut m := Model{}
	for key in ['2', '+', '3', 'x', '4', '='] { m.press(key) }
	assert m.expression == '14'
	m.press('+')
	m.press('6')
	m.press('=')
	assert m.expression == '20'
	m.press('7')
	assert m.expression == '7'
	m.press('+-')
	m.press('x2')
	m.press('=')
	assert m.expression == '49'
	m.press('C')
	for key in ['1', '2', '+', '3', '4', 'CE'] { m.press(key) }
	assert m.expression == '12+'
	m.press('5')
	m.press('=')
	assert m.expression == '17'
	m.press('<')
	assert m.expression == '1'
	m.press('C')
	m.press('.')
	m.press('.')
	assert m.expression == '0.'
}

fn test_sign_groups_and_clear_entry() {
	mut m := Model{ expression: '2*(3+4)' }
	m.press('+-')
	assert evaluate(m.expression)! == -14
	m.press('+-')
	assert evaluate(m.expression)! == 14
	m.press('CE')
	assert m.expression == '2*'
	m = Model{ expression: '1e-5' }
	m.press('+-')
	assert evaluate(m.expression)! == -0.00001
	m.press('CE')
	assert m.expression == ''
}
