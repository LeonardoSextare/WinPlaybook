// Plays the terminal on the home page like a real run: the command is typed at
// an uneven, human pace, with Tab completions, then each output line appears
// after its own pause (data-delay in overrides/home.html), with a random
// variation on every load.

const randomBetween = (min, max) => min + Math.random() * (max - min)
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

// Types the parts of the command one by one. Each part is a text node or a
// colored span; a part with data-tab appears at once, like a Tab completion,
// after cycling through the earlier matches listed in data-tab.
// Returns false if the terminal left the page before the end.
async function typeCommand(terminal, command) {
  const parts = [...command.childNodes]
  command.replaceChildren()
  command.classList.add("wp-terminal--shown")

  for (const part of parts) {
    const text = part.textContent
    const typedPart = part.cloneNode(false)
    typedPart.textContent = ""
    command.append(typedPart)

    if (part.dataset?.tab !== undefined) {
      const matches = [...part.dataset.tab.split(" ").filter(Boolean), text]
      for (const match of matches) {
        await sleep(randomBetween(250, 450))
        typedPart.textContent = match
      }
      await sleep(randomBetween(150, 300))
      continue
    }

    for (const char of text) {
      // Instant navigation replaces the page: stop if this terminal is gone.
      if (!terminal.isConnected) return false
      typedPart.textContent += char
      const pause = char === " " ? randomBetween(120, 260) : randomBetween(40, 130)
      await sleep(pause)
    }
  }
  return true
}

async function playTerminal(terminal) {
  const command = terminal.querySelector(".wp-terminal__command")
  const cursor = terminal.querySelector(".wp-terminal__cursor")
  const lines = terminal.querySelectorAll(".wp-terminal__output")

  terminal.classList.add("wp-terminal--typing")
  await sleep(randomBetween(500, 900))
  if (!(await typeCommand(terminal, command))) return

  // Enter: the cursor hides while the playbook runs, like in a real terminal.
  terminal.classList.remove("wp-terminal--typing")
  cursor.hidden = true

  for (const line of lines) {
    await sleep(Number(line.dataset.delay) * randomBetween(0.7, 1.3))
    if (!terminal.isConnected) return
    line.classList.add("wp-terminal--shown")
  }

  lines[lines.length - 1].append(cursor)
  cursor.hidden = false
}

// document$ is the theme's page-load event; it also fires after instant navigation.
document$.subscribe(() => {
  const terminal = document.querySelector(".wp-terminal")
  const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches
  if (terminal && !reduceMotion) {
    playTerminal(terminal)
  }
})
