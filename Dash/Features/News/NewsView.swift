//
//  NewsView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/22/24.
//https://thenextweb.com/

import SwiftUI
import WebKit

struct NewsView: View {
    let webURL = "https://thenextweb.com/"
    @State private var webView = WKWebView()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tech News")
                    .font(.custom("Chewy-Regular", size: 28))
                    .bold()
                    .padding(.top, 16)
                    .padding(.leading)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 3)

            WebView(url: webURL, webView: $webView)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: String
    @Binding var webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        self.webView = webView
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let removeAdsScript = """
                document.querySelectorAll('iframe, .ad, .ads, .advertisement, [id*="ad"]').forEach(el => el.remove());
            """
            webView.evaluateJavaScript(removeAdsScript, completionHandler: nil)
        }
    }
}
