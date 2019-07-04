//
//  PodcastDataManager.swift
//  PodcastApp
//
//  Created by Ben Scheirman on 7/3/19.
//  Copyright © 2019 NSScreencast. All rights reserved.
//

import Foundation

class PodcastDataManager {
    private let topPodcastsAPI = TopPodcastsAPI()
    private let searchClient = PodcastSearchAPI()

    func recommendedPodcasts(completion: @escaping (Result<[SearchResult], PodcastLoadingError>) -> Void) {
        topPodcastsAPI.fetchTopPodcasts(limit: 50, allowExplicit: false) { result in
            switch result {
            case .success(let response):
                let searchResults = response.feed.results.map(SearchResult.init)
                completion(.success(searchResults))

            case .failure(let error):
                completion(.failure(PodcastLoadingError.convert(from: error)))
            }
        }
    }

    func search(for term: String, completion: @escaping (Result<[SearchResult], PodcastLoadingError>) -> Void) {
        searchClient.search(for: term) { result in
            switch result {
            case .success(let response):
                let searchResults = response.results.map(SearchResult.init)
                completion(.success(searchResults))

            case .failure(let error): completion(.failure(PodcastLoadingError.convert(from: error)))
            }
        }
    }

    func lookup(podcastID: String, completion: @escaping (Result<SearchResult?, APIError>) -> Void) {
        searchClient.lookup(id: podcastID) { result in
            completion(result)
        }
    }

}
