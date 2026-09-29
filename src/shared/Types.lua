-- Shared type aliases for MVP session state.
-- Authoritative mutation lives on the server; clients only read snapshots.

export type Phase = "Day" | "Night" | "Won"

export type BuffId = "QuietPaws" | "SugarDash" | "LessonLeftover"

export type BuffCharge = {
	id: BuffId,
	charges: number,
}

export type SessionSnapshot = {
	phase: Phase,
	cycleIndex: number, -- 1-based day/night cycle count
	buffs: { BuffCharge },
	escapedThisNight: boolean,
	goalText: string,
}

export type QuizSubject = "Spelling" | "Math"

export type QuizQuestion = {
	id: string,
	subject: QuizSubject,
	prompt: string,
	choices: { string },
	correctIndex: number, -- 1-based; never trust client claims of correctness
	buffOnCorrect: BuffId,
}

export type InteractKind = "Latch" | "Phone" | "Lesson"

return nil
