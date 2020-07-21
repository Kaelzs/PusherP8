//
//  TextView.swift
//  macOS
//
//  Created by Kael Yang on 16/7/2020.
//

import Cocoa
import SwiftUI

/// A wrapper around NSTextView so we can get multiline text editing in SwiftUI.
struct TextView: NSViewRepresentable {
    @Binding private var text: String
    private var errorMessage: Binding<String>?

    init(text: Binding<String>, errorMessage: Binding<String>? = nil) {
        self._text = text
        self.errorMessage = errorMessage
    }

    func makeNSView(context: Context) -> NSScrollView {
        let text = NSTextView()
        text.backgroundColor = .textBackgroundColor
        text.delegate = context.coordinator
        text.isRichText = false
        text.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        text.autoresizingMask = [.width]
        text.translatesAutoresizingMaskIntoConstraints = true
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.isEditable = true

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = text
        scroll.drawsBackground = false

        return scroll
    }

    func updateNSView(_ view: NSScrollView, context: Context) {
        let text = view.documentView as? NSTextView
        text?.string = self.text

        guard context.coordinator.selectedRanges.count > 0 else {
            return
        }

        text?.selectedRanges = context.coordinator.selectedRanges
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextView
        var selectedRanges = [NSValue]()

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if replacementString?.contains("\t") == true {
                let newString = replacementString.unsafelyUnwrapped.replacingOccurrences(of: "\t", with: "    ")
                textView.replaceCharacters(in: affectedCharRange, with: newString)

                return false
            }
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
            self.selectedRanges = textView.selectedRanges

            if parent.errorMessage != nil,
               let stringData = textView.string.data(using: .utf8) {
                do {
                    try JSONSerialization.jsonObject(with: stringData, options: .allowFragments)
                    self.parent.errorMessage?.wrappedValue = ""
                } catch {
                    self.parent.errorMessage?.wrappedValue = error.localizedDescription
                }
            }
        }
    }
}
