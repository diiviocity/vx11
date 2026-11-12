// Five-column calculator: green LCD, black text, and a two-row equals key.
module main

import vx11
import vx11.examples.demo
import vx11.examples.calc

struct Button {
	key    string
	x      int
	y      int
	width  int
	height int
}

fn buttons(width int, height int) []Button {
	gap := 10
	cellw := (width - 40 - gap * 4) / 5
	cellh := (height - 246 - gap * 4) / 5
	mut result := []Button{}
	rows := [['<', 'CE', 'C', '+-', '%'], ['7', '8', '9', '/', '('], ['4', '5', '6', 'x', ')'],
		['1', '2', '3', '-', '='], ['x2', '0', '.', '+', '']]
	for row, keys in rows {
		for col, key in keys {
			if key == '' { continue }
			result << Button{
				key:    key
				x:      20 + col * (cellw + gap)
				y:      206 + row * (cellh + gap)
				width:  cellw
				height: if key == '=' {
					cellh * 2 + gap
				} else {
					cellh
				}
			}
		}
	}
	return result
}

fn hit(buttons []Button, x int, y int) string {
	for b in buttons {
		if x >= b.x && x < b.x + b.width && y >= b.y && y < b.y + b.height { return b.key }
	}
	return ''
}

fn render_calculator(mut canvas demo.Canvas, model &calc.Model, hover string) ! {
	canvas.rect(0, 0, canvas.width, canvas.height, '#23282b')!
	canvas.text(22, 31, 'CALCULATOR', '#dce3df', false)!
	canvas.text(canvas.width - 100, 31, 'V / X11', '#8d9a94', false)!
	canvas.round_rect(18, 50, canvas.width - 36, 134, 8, '#111713')!
	canvas.round_rect(22, 54, canvas.width - 44, 126, 6, '#a8ca7d')!
	canvas.text(38, 79, if model.message != '' {
		model.message
	} else if model.evaluated {
		'RESULT'
	} else {
		'EXPRESSION'
	}, '#26391b', false)!
	raw := model.display().replace('*', 'x')
	// Show the rightmost part of long expressions, keeping the LCD text inside it.
	scale := if raw.len <= 20 {
		3
	} else if raw.len <= 32 {
		2
	} else {
		1
	}
	visible := if raw.len > 60 { raw[raw.len - 60..] } else { raw }
	canvas.scaled_text(canvas.width - 40 - visible.len * 6 * scale, 143, visible, '#10170b', scale)!
	for b in buttons(canvas.width, canvas.height) {
		numeric := b.key in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']
		color := if b.key == hover {
			'#c8dba7'
		} else if b.key == '=' {
			'#9bc477'
		} else if numeric {
			'#e7e9e3'
		} else {
			'#b8c1b8'
		}
		canvas.round_rect(b.x, b.y + 3, b.width, b.height, 8, '#101613')!
		canvas.round_rect(b.x, b.y, b.width, b.height - 2, 8, color)!
		cx := b.x + b.width / 2
		baseline := b.y + b.height / 2 + 8
		if b.key == 'x2' {
			canvas.scaled_text(cx - 12, baseline, 'x', '#182019', 2)!
			canvas.scaled_text(cx + 4, baseline - 12, '2', '#182019', 1)!
		} else {
			canvas.centered(cx, baseline, b.key, '#182019', true)!
		}
	}
	canvas.text(22, canvas.height - 18, 'Enter =    Backspace <    Esc C    Q close', '#a5b2a9', false)!
	canvas.present()!
}

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	mut window := display.new_window(
		title:  'Calculator - V / X11'
		width:  480
		height: 660
		events: vx11.exposure_mask | vx11.structure_notify_mask | vx11.key_press_mask | vx11.button_press_mask | vx11.pointer_motion_mask | vx11.leave_window_mask
	)!
	defer { window.destroy() }
	demo.minimum_size(display, window, 480, 660)!
	mut canvas := demo.new_canvas(display, window, 480, 660)!
	defer { canvas.close() }
	mut model := calc.Model{}
	mut hover := ''
	window.show()!
	render_calculator(mut canvas, model, hover)!
	if canvas.finish_preview()! { return }
	for {
		event := display.next_event()!
		if window.should_close(event) { break }
		if event.kind == vx11.key_press {
			text := display.key_text(event)!
			if text in ['q', 'Q'] { break }
			key := match text {
				'\r', '\n', '=' { '=' }
				'\x08', '\x7f' { '<' }
				'\x1b', 'c', 'C' { 'C' }
				'e', 'E' { 'CE' }
				's', 'S' { 'x2' }
				'n', 'N' { '+-' }
				'*' { 'x' }
				else { text }
			}
			model.press(key)
		}
		if button := event.button() {
			if button.button == 1 {
				key := hit(buttons(canvas.width, canvas.height), button.x, button.y)
				if key != '' { model.press(key) }
			}
		}
		if motion := event.motion() {
			next_hover := hit(buttons(canvas.width, canvas.height), motion.x, motion.y)
			if next_hover == hover { continue }
			hover = next_hover
		}
		if event.kind == vx11.leave_notify { hover = '' }
		if size := event.configure() { canvas.resize(size.width, size.height)! }
		render_calculator(mut canvas, model, hover)!
	}
}
