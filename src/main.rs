use azookey_binding::{ComposingText, KanaKanjiConverter};

fn main() {
    let input = "seido";
    let kana_kanji_converter = KanaKanjiConverter::new();

    let composing_text = ComposingText::new();
    composing_text.insert_at_cursor_position(input);

    let result = kana_kanji_converter.request_candidates(&composing_text, "");

    println!("{} -> {:?}", input, result);
}
