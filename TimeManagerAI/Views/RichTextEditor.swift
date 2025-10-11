import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor.systemBackground
        textView.textColor = UIColor.label
        textView.allowsEditingTextAttributes = true
        textView.dataDetectorTypes = [.link, .phoneNumber]

        let toolbar = createToolbar(context: context)
        textView.inputAccessoryView = toolbar

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if !uiView.attributedText.isEqual(to: attributedText) {
            let currentSelection = uiView.selectedRange
            uiView.attributedText = attributedText

            if currentSelection.location <= uiView.attributedText.length {
                uiView.selectedRange = currentSelection
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func createToolbar(context: Context) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let boldButton = UIBarButtonItem(
            title: "B",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.toggleBold)
        )
        boldButton.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)

        let italicButton = UIBarButtonItem(
            title: "I",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.toggleItalic)
        )
        italicButton.setTitleTextAttributes([.font: UIFont.italicSystemFont(ofSize: 16)], for: .normal)

        let underlineButton = UIBarButtonItem(
            title: "U",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.toggleUnderline)
        )

        let linkButton = UIBarButtonItem(
            title: "🔗",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.addLink)
        )

        let redButton = UIBarButtonItem(
            title: "🔴",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.setRedColor)
        )

        let orangeButton = UIBarButtonItem(
            title: "🟠",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.setOrangeColor)
        )

        let yellowButton = UIBarButtonItem(
            title: "🟡",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.setYellowColor)
        )

        let blackButton = UIBarButtonItem(
            title: "⚫",
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.setBlackColor)
        )

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let hideButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.hideKeyboard))

        toolbar.items = [
            boldButton, flexSpace,
            italicButton, flexSpace,
            underlineButton, flexSpace,
            linkButton, flexSpace,
            redButton, flexSpace,
            orangeButton, flexSpace,
            yellowButton, flexSpace,
            blackButton, flexSpace,
            hideButton
        ]

        return toolbar
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }

        @objc func toggleBold() {
            guard let textView = getTextView() else { return }
            let range = textView.selectedRange
            if range.length == 0 { return }

            let currentText = NSMutableAttributedString(attributedString: textView.attributedText)
            let currentFont = currentText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 16)

            let newFont: UIFont
            if currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                newFont = UIFont.systemFont(ofSize: currentFont.pointSize)
            } else {
                newFont = UIFont.boldSystemFont(ofSize: currentFont.pointSize)
            }

            currentText.addAttribute(.font, value: newFont, range: range)
            textView.attributedText = currentText
            parent.attributedText = currentText
        }

        @objc func toggleItalic() {
            guard let textView = getTextView() else { return }
            let range = textView.selectedRange
            if range.length == 0 { return }

            let currentText = NSMutableAttributedString(attributedString: textView.attributedText)
            let currentFont = currentText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 16)

            let newFont: UIFont
            if currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                newFont = UIFont.systemFont(ofSize: currentFont.pointSize)
            } else {
                newFont = UIFont.italicSystemFont(ofSize: currentFont.pointSize)
            }

            currentText.addAttribute(.font, value: newFont, range: range)
            textView.attributedText = currentText
            parent.attributedText = currentText
        }

        @objc func toggleUnderline() {
            guard let textView = getTextView() else { return }
            let range = textView.selectedRange
            if range.length == 0 { return }

            let currentText = NSMutableAttributedString(attributedString: textView.attributedText)
            let currentUnderline = currentText.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0

            let newUnderlineStyle = currentUnderline == 0 ? NSUnderlineStyle.single.rawValue : 0
            currentText.addAttribute(.underlineStyle, value: newUnderlineStyle, range: range)

            textView.attributedText = currentText
            parent.attributedText = currentText
        }

        @objc func addLink() {
            guard let textView = getTextView() else { return }
            let range = textView.selectedRange
            if range.length == 0 { return }

            let alert = UIAlertController(title: "Add Link", message: "Enter URL", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "https://example.com"
                textField.keyboardType = .URL
            }

            alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
                guard let urlString = alert.textFields?.first?.text,
                      let url = URL(string: urlString) else { return }

                let currentText = NSMutableAttributedString(attributedString: textView.attributedText)
                currentText.addAttribute(.link, value: url, range: range)
                currentText.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
                currentText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)

                textView.attributedText = currentText
                self.parent.attributedText = currentText
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }

        @objc func setRedColor() {
            setTextColor(.systemRed)
        }

        @objc func setOrangeColor() {
            setTextColor(.systemOrange)
        }

        @objc func setYellowColor() {
            setTextColor(.systemYellow)
        }

        @objc func setBlackColor() {
            setTextColor(.label)
        }

        private func setTextColor(_ color: UIColor) {
            guard let textView = getTextView() else { return }
            let range = textView.selectedRange
            if range.length == 0 { return }

            let currentText = NSMutableAttributedString(attributedString: textView.attributedText)
            currentText.addAttribute(.foregroundColor, value: color, range: range)

            textView.attributedText = currentText
            parent.attributedText = currentText
        }

        @objc func hideKeyboard() {
            getTextView()?.resignFirstResponder()
        }

        private func getTextView() -> UITextView? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return nil }

            return findTextView(in: window)
        }

        private func findTextView(in view: UIView) -> UITextView? {
            if let textView = view as? UITextView {
                return textView
            }
            for subview in view.subviews {
                if let textView = findTextView(in: subview) {
                    return textView
                }
            }
            return nil
        }
    }
}