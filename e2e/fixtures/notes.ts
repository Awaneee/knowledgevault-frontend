/** Realistic notes seeded through the API so every screen has content. */
export const SEED_NOTES = [
  'Study plan for the compilers exam: revise lexical analysis, DFA minimisation and LL(1) parsing tables. Practise two past papers on Saturday.',
  'Idea: build a habit tracker that nudges you with a short summary of your week every Sunday evening.',
  'Remind me to renew the library card before 15 November and return the Dragon Book.',
  'Meeting notes with Sid: agreed to ship the search feature first, then polish onboarding. Sid owns the API docs.',
  'Reference: Transformers use scaled dot-product attention — softmax(QK^T / sqrt(d_k)) V. Multi-head attention runs this in parallel subspaces.',
  'Todo: buy groceries — oats, bananas, coffee beans and paneer for dinner on Friday.',
  'Question: why does batch normalisation help optimisation? Read the paper on smoothing the loss landscape.',
  'Event: hackathon at Thapar on 8 November, team of four, theme is AI for education.',
];

export const UPLOAD_TEXT = `Lecture 1 — Lexical Analysis
A lexer turns a character stream into tokens.
Regular expressions describe tokens; they compile to NFAs, then DFAs.
Maximal munch: always take the longest matching prefix.`;
