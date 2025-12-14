// returns first candidate

import Foundation

import KanaKanjiConverterModule

import ffi

nonisolated(unsafe) var execURL = URL(filePath: "")
public class ComposingTextWrapper {
    var value: ComposingText

    init(value: ComposingText) {
        self.value = value
    }
}
@_silgen_name("CreateKanaKanjiConverter")
public func create_kana_kanji_converter() -> UnsafeMutablePointer<KanaKanjiConverter> {
    let converter = KanaKanjiConverter()
    return Unmanaged.passRetained(converter).toOpaque().assumingMemoryBound(
        to: KanaKanjiConverter.self)
}
@_silgen_name("DestroyKanaKanjiConverter")
public func destroy_kana_kanji_converter(
    _ converter: UnsafeMutablePointer<KanaKanjiConverter>
) {
    Unmanaged<KanaKanjiConverter>.fromOpaque(converter).release()
}
@_silgen_name("CreateComposingText")
public func create_composing_text() -> UnsafeMutablePointer<ComposingTextWrapper> {
    let c = ComposingTextWrapper(value: ComposingText())
    return Unmanaged.passRetained(c).toOpaque().assumingMemoryBound(to: ComposingTextWrapper.self)
}
@_silgen_name("DestroyComposingText")
public func destroy_composing_text(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>
) {
    Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).release()
}
@_silgen_name("KanaKanjiConverter_RequestCandidates")
public func kana_kanji_converter_request_candidates(
    _ converter: UnsafeMutablePointer<KanaKanjiConverter>,
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ lengthPtr: UnsafeMutablePointer<Int>,
    _ context: UnsafePointer<CChar>,
    _ dictionaryPath: UnsafePointer<CChar>,
    _ weightPath: UnsafePointer<CChar>,
) -> UnsafeMutablePointer<UnsafeMutablePointer<FFICandidate>> {
    let options = ConvertRequestOptions(
        requireJapanesePrediction: true,
        requireEnglishPrediction: false,
        keyboardLanguage: .ja_JP,
        learningType: .nothing,
        dictionaryResourceURL: URL(filePath: String(cString: dictionaryPath)),
        memoryDirectoryURL: URL(filePath: "./"),
        sharedContainerURL: URL(filePath: "./"),
        zenzaiMode: .on(
            weight: URL(filePath: String(cString: weightPath)), inferenceLimit: 1,
            requestRichCandidates: true, personalizationMode: nil,
            versionDependentMode: .v3(.init(profile: "", leftSideContext: String(cString: context)))
        ),
        preloadDictionary: true,
        metadata: .init(versionString: "rs-azookey-binding")
    )

    // requestCandidatesがasyncになったため、同期的に待つ
    var candidates: ConversionResult!
    let semaphore = DispatchSemaphore(value: 0)
    let converterAddr = Int(bitPattern: converter)
    let composingTextAddr = Int(bitPattern: composingText)
    Task {
        guard let cPtr = UnsafeRawPointer(bitPattern: converterAddr),
            let ctPtr = UnsafeRawPointer(bitPattern: composingTextAddr) else {
            semaphore.signal()
            return
        }
        let c = Unmanaged<KanaKanjiConverter>.fromOpaque(cPtr).takeUnretainedValue()
        let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(ctPtr).takeUnretainedValue()
        candidates = await c.requestCandidates(ct.value, options: options)
        semaphore.signal()
    }
    semaphore.wait()

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
public func kana_kanji_converter_stop_composition(
    _ converter: UnsafeMutablePointer<KanaKanjiConverter>,
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>
) {
    let c = Unmanaged<KanaKanjiConverter>.fromOpaque(converter).takeUnretainedValue()
    c.stopComposition()
}
@_silgen_name("ComposingText_InsertAtCursorPosition")
public func composing_text_insert_at_cursor_position(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ text: UnsafePointer<CChar>,
) {
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()
    let str = String(cString: text)
    ct.value.insertAtCursorPosition(str, inputStyle: .roman2kana)
}
@_silgen_name("ComposingText_DeleteForwardFromCursorPosition")
public func composing_text_delete_forward_from_cursor_position(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ count: Int32
) {
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()
    ct.value.deleteForwardFromCursorPosition(count: Int(count))
}
@_silgen_name("ComposingText_DeleteBackwardFromCursorPosition")
public func composing_text_delete_backward_from_cursor_position(
    _ composingText: UnsafeMutablePointer<ComposingTextWrapper>,
    _ count: Int32
) {
    let ct = Unmanaged<ComposingTextWrapper>.fromOpaque(composingText).takeUnretainedValue()
    ct.value.deleteBackwardFromCursorPosition(count: Int(count))
}
