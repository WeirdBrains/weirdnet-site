// Editing rules for a text field, tested without any UI toolkit.
use weirdnet_text::TextField;

fn main() {
    let mut field = TextField::new();
    for ch in "git".chars() {
        field.replace(None, &ch.to_string()); // typing inserts at the caret
    }
    field.append_selected("hub.com"); // an inline completion, selected
    field.right(); // Right accepts it
    assert_eq!((field.text(), field.cursor()), ("github.com", 10));

    // Backspace removes a whole grapheme cluster, not one byte or code point.
    let mut emoji = TextField::new();
    emoji.replace(None, "hi 👋🏽");
    emoji.backspace();
    assert_eq!(emoji.text(), "hi ");

    // One-line fields turn pasted line breaks into spaces; multiline ones keep them.
    let mut chat = TextField::multiline();
    chat.replace(None, "line one\r\nline two");
    assert_eq!(chat.text(), "line one\nline two");
}
