//
//  TextView.swift
//  iOS
//
//  Created by Kael Yang on 16/7/2020.
//

import UIKit
import SwiftUI

/// A wrapper around UITextView so we can get multiline text editing in SwiftUI.
struct TextView: UIViewRepresentable {
    @Binding private var text: String
    private var errorMessage: Binding<String>?

    init(text: Binding<String>, errorMessage: Binding<String>? = nil) {
        self._text = text
        self.errorMessage = errorMessage
    }

    func makeUIView(context: Context) -> UITextView {
        let text = UITextView()
        text.backgroundColor = .secondarySystemBackground
        text.delegate = context.coordinator
        text.font = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        text.isEditable = true

        return text
    }

    func updateUIView(_ view: UITextView, context: Context) {
        view.text = self.text
        view.selectedRange = context.coordinator.selectedRanges
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView
        var selectedRanges = NSRange()

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
            self.selectedRanges = textView.selectedRange

            if parent.errorMessage != nil,
               let stringData = textView.text.data(using: .utf8) {
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
