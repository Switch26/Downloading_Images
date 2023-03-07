//
//  DataDecoder.swift
//  Downloading_Images
//
//  Created by Serguei Vinnitskii on 3/7/23.
//

import Foundation

protocol DataDecoderProtocol {
    func decode<T: Decodable>(data: Data) throws -> T
}

class DataDecoder: DataDecoderProtocol {
    private var jsonDecoder: JSONDecoder
    
    init(jsonDecoder: JSONDecoder = JSONDecoder()){
        self.jsonDecoder = jsonDecoder
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase //some_thing => someThing
    }
    
    func decode<T: Decodable>(data: Data) throws -> T {
        return try jsonDecoder.decode(T.self, from: data)
    }
}
