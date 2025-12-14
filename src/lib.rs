use std::os::raw::c_void;

use libc::c_int;
use serde::{Deserialize, Serialize};

// FFI declarations for KanaKanjiConverter Swift bindings
// Note: These functions are now thread-safe and can be called from any thread.
// The Swift side no longer uses @MainActor, making them suitable for
// background thread usage in Rust + Tauri applications.
unsafe extern "C" {
    /// Creates a new KanaKanjiConverter instance
    /// Thread-safe: Can be called from any thread
    pub fn CreateKanaKanjiConverter() -> *mut c_void;

    /// Destroys a KanaKanjiConverter instance
    /// Thread-safe: Can be called from any thread
    pub fn DestroyKanaKanjiConverter(converter: *mut c_void);

    /// Creates a new ComposingText instance
    /// Thread-safe: Can be called from any thread
    pub fn CreateComposingText() -> *mut c_void;

    /// Destroys a ComposingText instance
    /// Thread-safe: Can be called from any thread
    pub fn DestroyComposingText(composingText: *mut c_void);

    /// Requests conversion candidates
    /// Thread-safe: Can be called from any thread
    /// Note: This function blocks until conversion is complete
    pub fn KanaKanjiConverter_RequestCandidates(
        converter: *mut c_void,
        composingText: *mut c_void,
        lengthPtr: *mut c_int,
        context: *const libc::c_char,
        dictionary_path: *const libc::c_char,
        weight_path: *const libc::c_char,
    ) -> *mut *mut FFICandidate;

    /// Stops the current composition session
    /// Thread-safe: Can be called from any thread
    pub fn KanaKanjiConverter_StopComposition(converter: *mut c_void);

    /// Inserts text at cursor position
    /// Thread-safe: Can be called from any thread
    pub fn ComposingText_InsertAtCursorPosition(
        composingText: *mut c_void,
        text: *const libc::c_char,
    );

    /// Deletes characters forward from cursor
    /// Thread-safe: Can be called from any thread
    pub fn ComposingText_DeleteForwardFromCursorPosition(
        composingText: *mut c_void,
        count: libc::c_int,
    );

    /// Deletes characters backward from cursor
    /// Thread-safe: Can be called from any thread
    pub fn ComposingText_DeleteBackwardFromCursorPosition(
        composingText: *mut c_void,
        count: libc::c_int,
    );
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub struct FFICandidate {
    text: *mut libc::c_char,
    corresponding_count: libc::c_int,
}

/// Conversion candidate returned from the converter
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Candidate {
    pub text: String,
    pub corresponding_count: i32,
}

/// Kana-Kanji converter instance
///
/// # Thread Safety
/// This type can be used from any thread. The underlying Swift implementation
/// no longer uses @MainActor, making it safe for background thread usage.
///
/// # Note
/// Each instance should only be accessed from one thread at a time.
/// The Rust side is responsible for ensuring no concurrent access occurs.
pub struct KanaKanjiConverter {
    pub converter: *mut c_void,
}

/// Composing text state for input method
///
/// # Thread Safety
/// This type can be used from any thread, but concurrent access to the
/// same instance must be prevented by the caller.
pub struct ComposingText {
    pub composing_text: *mut c_void,
}

impl KanaKanjiConverter {
    /// Creates a new KanaKanjiConverter instance
    ///
    /// # Thread Safety
    /// Can be called from any thread
    pub fn new() -> Self {
        unsafe {
            let converter = CreateKanaKanjiConverter();
            if converter.is_null() {
                panic!("Failed to create KanaKanjiConverter");
            }
            Self { converter }
        }
    }

    /// Requests conversion candidates for the given composing text
    ///
    /// # Thread Safety
    /// Can be called from any thread. This function blocks until conversion
    /// is complete (the Swift async function is synchronously awaited).
    ///
    /// # Arguments
    /// * `composing_text` - The current composing text state
    /// * `context` - Left-side context for the conversion
    /// * `dictionary_path` - Path to the dictionary file
    /// * `weight_path` - Path to the AI model weights (Zenz)
    ///
    /// # Returns
    /// Vector of conversion candidates
    pub fn request_candidates(
        &self,
        composing_text: &ComposingText,
        context: &str,
        dictionary_path: &str,
        weight_path: &str,
    ) -> Vec<Candidate> {
        unsafe {
            let c_str = std::ffi::CString::new(context).expect("CString::new failed");
            let mut length: c_int = 0;
            let dict_c_str = std::ffi::CString::new(dictionary_path).expect("CString::new failed");
            let weight_c_str = std::ffi::CString::new(weight_path).expect("CString::new failed");
            let candidates_ptr = KanaKanjiConverter_RequestCandidates(
                self.converter,
                composing_text.composing_text,
                &mut length,
                c_str.as_ptr(),
                dict_c_str.as_ptr(),
                weight_c_str.as_ptr(),
            );
            if candidates_ptr.is_null() {
                panic!("Failed to get candidates");
            }

            let mut candidates = Vec::new();
            for i in 0..length {
                let candidate = *(*candidates_ptr.offset(i as isize));
                let text = std::ffi::CStr::from_ptr(candidate.text)
                    .to_string_lossy()
                    .into_owned();
                let corresponding_count = candidate.corresponding_count;
                candidates.push(Candidate {
                    text,
                    corresponding_count,
                });
            }
            candidates
        }
    }

    /// Stops the current composition session and resets internal state
    ///
    /// # Thread Safety
    /// Can be called from any thread
    pub fn stop_composition(&self) {
        unsafe {
            KanaKanjiConverter_StopComposition(self.converter);
        }
    }
}

impl Drop for KanaKanjiConverter {
    fn drop(&mut self) {
        unsafe {
            DestroyKanaKanjiConverter(self.converter);
        }
    }
}

impl ComposingText {
    /// Creates a new ComposingText instance
    ///
    /// # Thread Safety
    /// Can be called from any thread
    pub fn new() -> Self {
        unsafe {
            let composing_text = CreateComposingText();
            if composing_text.is_null() {
                panic!("Failed to create ComposingText");
            }
            Self { composing_text }
        }
    }

    /// Inserts text at the current cursor position
    ///
    /// # Thread Safety
    /// Can be called from any thread
    ///
    /// # Arguments
    /// * `text` - The text to insert
    pub fn insert_at_cursor_position(&self, text: &str) {
        unsafe {
            let c_str = std::ffi::CString::new(text).expect("CString::new failed");
            ComposingText_InsertAtCursorPosition(self.composing_text, c_str.as_ptr());
        }
    }

    /// Deletes characters forward from the cursor position
    ///
    /// # Thread Safety
    /// Can be called from any thread
    ///
    /// # Arguments
    /// * `count` - Number of characters to delete
    pub fn delete_forward_from_cursor_position(&self, count: i32) {
        unsafe {
            ComposingText_DeleteForwardFromCursorPosition(self.composing_text, count);
        }
    }

    /// Deletes characters backward from the cursor position
    ///
    /// # Thread Safety
    /// Can be called from any thread
    ///
    /// # Arguments
    /// * `count` - Number of characters to delete
    pub fn delete_backward_from_cursor_position(&self, count: i32) {
        unsafe {
            ComposingText_DeleteBackwardFromCursorPosition(self.composing_text, count);
        }
    }
}

impl Drop for ComposingText {
    fn drop(&mut self) {
        unsafe {
            DestroyComposingText(self.composing_text);
        }
    }
}
