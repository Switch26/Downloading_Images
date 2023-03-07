//
//  ContentView.swift
//  Downloading_Images
//
//  Created by Serguei Vinnitskii on 2/24/23.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct myTestStruct {
    download(url: , toFile: <#T##URL#>, completion: <#T##(Result<URL, DownloadError>) -> Void#>)
}
