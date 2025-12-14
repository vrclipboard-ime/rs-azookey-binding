// returns first candidate

import Foundation

import KanaKanjiConverterModuleWithDefaultDictionary

import ffi

public class ComposingTextWrapper {
    var value: ComposingText

    init(value: ComposingText) {
        self.value = value
    }
}
@_silgen_name("CreateKanaKanjiConverter")
@MainActor public func create_kana_kanji_converter() -> UnsafeMutablePointer<KanaKanjiConverter> {
    let converter = KanaKanjiConverter()
    return Unmanaged.passRetained(converter).toOpaque().assumingMemoryBound(
        to: KanaKanjiConverter.self)
}
@_silgen_name("DestroyKanaKanjiConverter")
@MainActor public func destroy_kana_kanji_converter(
    _ converter: UnsafeMutablePointer<KanaKanjiConverter>
) {
    Unmanaged<KanaKanjiConverter>.fromOpaque(converter).release()
}
@_silgen_name("CreateComposingText")
@MainActor public func create_composing_text() -> UnsafeMutablePointer<ComposingTextWrapper> {
    let c = ComposingTextWrapper(value: ComposingText())
    return Unmanaged.passRetained(c).toOpaque().assumingMemoryBound(to: ComposingTextWrapper.self)
}
@_silgen_name("DestroyComposingText")
@MainActor public func destroy_composing_text(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>
) {
    Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).release()
}
@_silgen_name("KanaKanjiConverter_RequestCandidates")
@MainActor public func kana_kanji_converter_request_candidates(
    _ converter: UnsafeMutablePointer<KanaKanjiConverter>,
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ lengthPtr: UnsafeMutablePointer<Int>,
    _ context: UnsafePointer<CChar>
) -> UnsafeMutablePointer<UnsafeMutablePointer<FFICandidate>> {
    let c = Unmanaged<KanaKanjiConverter>.fromOpaque(converter).takeUnretainedValue()
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()

    let options = ConvertRequestOptions.withDefaultDictionary(
        requireJapanesePrediction: true,
        requireEnglishPrediction: false,
        keyboardLanguage: .ja_JP,
        learningType: .nothing,
        memoryDirectoryURL: URL(filePath: "./"),
        sharedContainerURL: URL(filePath: "./"),
        zenzaiMode: .on(
            weight: URL(filePath: "./ggml-model-Q5_K_M.gguf"), inferenceLimit: 1,
            requestRichCandidates: true, personalizationMode: nil,
            versionDependentMode: .v3(.init(profile: "", leftSideContext: String(cString: context)))
        ),
        preloadDictionary: true,
        metadata: .init(versionString: "rs-azookey-binding")
    )

    let candidates: ConversionResult = c.requestCandidates(ct.value, options: options)

    var result: [FFICandidate] = []

    for i in 0..<candidates.mainResults.count {
        let candidate = candidates.mainResults[i]

        let text = candidate.text
        let correspondingCount = candidate.correspondingCount

        result.append(
            FFICandidate(
                text: UnsafeMutablePointer(mutating: (text as NSString).utf8String!),
                correspondingCount: Int32(correspondingCount),
            )
        )
    }

    let pointer = UnsafeMutablePointer<UnsafeMutablePointer<FFICandidate>>.allocate(
        capacity: result.count)
    for i in 0..<result.count {
        pointer[i] = UnsafeMutablePointer<FFICandidate>.allocate(capacity: 1)
        pointer[i].pointee = result[i]
    }
    lengthPtr.pointee = result.count
    return pointer
}
@_silgen_name("KanaKanjiConverter_StopComposition")
@MainActor public func kana_kanji_converter_stop_composition(
    _ converter: UnsafeMutablePointer<KanaKanjiConverter>,
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>
) {
    let c = Unmanaged<KanaKanjiConverter>.fromOpaque(converter).takeUnretainedValue()
    c.stopComposition()
}
@_silgen_name("ComposingText_InsertAtCursorPosition")
@MainActor public func composing_text_insert_at_cursor_position(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ text: UnsafePointer<CChar>,
) {
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()
    let str = String(cString: text)
    ct.value.insertAtCursorPosition(str, inputStyle: .roman2kana)
}
@_silgen_name("ComposingText_DeleteForwardFromCursorPosition")
@MainActor public func composing_text_delete_forward_from_cursor_position(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ count: Int32
) {
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()
    ct.value.deleteForwardFromCursorPosition(count: Int(count))
}
@_silgen_name("ComposingText_DeleteBackwardFromCursorPosition")
@MainActor public func composing_text_delete_backward_from_cursor_position(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ count: Int32
) {
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()
    ct.value.deleteBackwardFromCursorPosition(count: Int(count))
}
