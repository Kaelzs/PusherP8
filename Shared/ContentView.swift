//
//  ContentView.swift
//  Shared
//
//  Created by Kael Yang on 16/7/2020.
//

import SwiftUI

struct TitleAndTextField: View {
    var title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
            TextField("fill \(title)", text: $text)
        }
    }
}

struct ContentView: View {
    @AppStorage("deviceToken") var deviceToken: String = ""
    @AppStorage("keyID") var keyID: String = ""
    @AppStorage("teamID") var teamID: String = ""
    @AppStorage("bundleID") var bundleID: String = ""
    @AppStorage("p8") var p8: String = ""
    @AppStorage("payload") var payload: String = ""
    @AppStorage("production") var production: Bool = true

    @State var textViewErrorMessage: String = ""

    var body: some View {
        let content = VStack {
            TitleAndTextField("Device Token", text: $deviceToken)
            TitleAndTextField("Key ID", text: $keyID)
            TitleAndTextField("team ID", text: $teamID)
            TitleAndTextField("bundle ID", text: $bundleID)
            TitleAndTextField("P8", text: $p8)
            VStack(alignment: .leading, spacing: 0) {
                Text("payload")
                TextView(text: $payload, errorMessage: $textViewErrorMessage).frame(height: 200).onAppear {
                    let previous = payload
                    payload = ""
                    payload = previous
                }
                if textViewErrorMessage.isEmpty {
                    Text("valid json").foregroundColor(.green)
                } else {
                    Text(textViewErrorMessage).foregroundColor(.red)
                }
            }
            Spacer(minLength: 10)
            HStack {
                Toggle("production", isOn: $production)
                Spacer()
                Button("Send") {
                    self.sendRequest()
                }
            }
        }.padding(15)

        #if os(iOS)
        return ScrollView {
            content
        }
        #else
        return content
        #endif
    }

    func sendRequest() {
        let jwt = JWT(keyID: keyID, teamID: teamID, issueDate: Date(), expireDuration: 60 * 60)
        guard let token = try? jwt.sign(with: p8) else {
            return
        }
        var request = URLRequest(url: URL(string: (production ? "https://api.push.apple.com:443/3/device/" : "https://api.sandbox.push.apple.com:443/3/device/") + deviceToken)!)
        request.httpMethod = "POST"
        request.addValue("bearer \(token)", forHTTPHeaderField: "authorization")
        request.addValue(bundleID, forHTTPHeaderField: "apns-topic")
        request.httpBody = payload.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let data = data else {
                print("Empty data")
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
