use std::os::raw::c_void;

use libc::c_int;

use serde::{Deserialize, Serialize};

unsafe extern "C" {
    pub fn CreateKanaKanjiConverter() -> *mut c_void;
    pub fn DestroyKanaKanjiConverter(converter: *mut c_void);
    pub fn CreateComposingText() -> *mut c_void;
    pub fn DestroyComposingText(composingText: *mut c_void);
    pub fn KanaKanjiConverter_RequestCandidates(
        converter: *mut c_void,
        composingText: *mut c_void,
        lengthPtr: *mut c_int,
        context: *const libc::c_char,
    ) -> *mut *mut FFICandidate;
    pub fn KanaKanjiConverter_StopComposition(converter: *mut c_void);
    pub fn ComposingText_InsertAtCursorPosition(
        composingText: *mut c_void,
        text: *const libc::c_char,
    );
    pub fn ComposingText_DeleteForwardFromCursorPosition(
        composingText: *mut c_void,
        count: libc::c_int,
    );
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Candidate {
    pub text: String,
    pub corresponding_count: i32,
}

pub struct KanaKanjiConverter {
    pub converter: *mut c_void,
}

pub struct ComposingText {
    pub composing_text: *mut c_void,
}

impl KanaKanjiConverter {
    pub fn new() -> Self {
        unsafe {
            let converter = CreateKanaKanjiConverter();
            if converter.is_null() {
                panic!("Failed to create KanaKanjiConverter");
            }
            Self { converter }
        }
    }

    pub fn request_candidates(
        &self,
        composing_text: &ComposingText,
        context: &str,
    ) -> Vec<Candidate> {
        unsafe {
            let c_str = std::ffi::CString::new(context).expect("CString::new failed");
            let mut length: c_int = 0;
            let candidates_ptr = KanaKanjiConverter_RequestCandidates(
                self.converter,
                composing_text.composing_text,
                &mut length,
                c_str.as_ptr(),
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
    pub fn new() -> Self {
        unsafe {
            let composing_text = CreateComposingText();
            if composing_text.is_null() {
                panic!("Failed to create ComposingText");
            }
            Self { composing_text }
        }
    }

    pub fn insert_at_cursor_position(&self, text: &str) {
        unsafe {
            let c_str = std::ffi::CString::new(text).expect("CString::new failed");
            ComposingText_InsertAtCursorPosition(self.composing_text, c_str.as_ptr());
        }
    }

    pub fn delete_forward_from_cursor_position(&self, count: i32) {
        unsafe {
            ComposingText_DeleteForwardFromCursorPosition(self.composing_text, count);
        }
    }

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
