import SwiftUI
import AppKit

/// Preserve real tabs, newlines and repeated spaces in the source editor.
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let editor = scroll.documentView as! NSTextView
        editor.isRichText = false
        editor.allowsUndo = true
        editor.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        editor.textContainerInset = NSSize(width: 6, height: 8)
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        editor.isAutomaticSpellingCorrectionEnabled = false
        editor.setAccessibilityLabel("要注入的文字")
        editor.delegate = context.coordinator
        editor.string = text
        context.coordinator.lastSynchronizedText = text
        editor.isEditable = isEditable
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let editor = scroll.documentView as? NSTextView else { return }
        editor.isEditable = isEditable
        context.coordinator.synchronize(text, with: editor)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        var lastSynchronizedText: String
        private var pendingExternalText: String?
        private var isApplyingExternalText = false

        init(_ parent: PlainTextEditor) {
            self.parent = parent
            lastSynchronizedText = parent.text
        }

        func synchronize(_ text: String, with editor: NSTextView) {
            if editor.hasMarkedText() {
                // Keep the IME's uncommitted composition intact. Only queue a
                // value that actually changed outside the text view.
                pendingExternalText = text == lastSynchronizedText ? nil : text
                return
            }

            // NSTextView can finish an IME composition before SwiftUI has
            // delivered the matching Binding update. If that stale snapshot
            // reaches us in that window, preserve and publish the editor text.
            if pendingExternalText == nil,
               text == lastSynchronizedText,
               editor.string != lastSynchronizedText {
                let editedText = editor.string
                lastSynchronizedText = editedText
                if parent.text != editedText { parent.text = editedText }
                return
            }

            let textToApply = pendingExternalText ?? text
            pendingExternalText = nil
            applyExternalText(textToApply, to: editor)
        }

        func textDidChange(_ notification: Notification) {
            guard let editor = notification.object as? NSTextView else { return }
            guard !isApplyingExternalText, !editor.hasMarkedText() else { return }

            if let pendingExternalText {
                self.pendingExternalText = nil
                applyExternalText(pendingExternalText, to: editor)
                if parent.text != pendingExternalText { parent.text = pendingExternalText }
                return
            }

            let committedText = editor.string
            lastSynchronizedText = committedText
            if parent.text != committedText { parent.text = committedText }
        }

        private func applyExternalText(_ text: String, to editor: NSTextView) {
            if editor.string != text {
                isApplyingExternalText = true
                editor.string = text
                editor.undoManager?.removeAllActions()
                isApplyingExternalText = false
            }
            lastSynchronizedText = text
        }

        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard selector == #selector(NSResponder.insertTab(_:)), textView.isEditable else { return false }
            textView.insertText("\t", replacementRange: textView.selectedRange())
            return true
        }
    }
}
