//
//  PodcastFeedLoader.swift
//  PodcastApp
//
//  Created by Ben Scheirman on 5/7/19.
//  Copyright © 2019 NSScreencast. All rights reserved.
//

import Foundation
import FeedKit

class PodcastFeedLoader {
    func fetch(feed: URL, completion: @escaping (Swift.Result<Podcast, PodcastLoadingError>) -> Void) {

        let req = URLRequest(url: feed, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.loadError(error)))
                }
                return
            }

            let http = response as! HTTPURLResponse
            switch http.statusCode {
            case 200:
                if let data = data {
                    self.loadFeed(data: data, completion: completion)
                }

            case 404:
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
           
            default:
                DispatchQueue.main.async {                    completion(.failure(.requestFailed(http.statusCode)))
                }
            }
        }.resume()
    }

    private func loadFeed(data: Data, completion: @escaping (Swift.Result<Podcast, PodcastLoadingError>) -> Void) {
        let parser = FeedParser(data: data)
        parser.parseAsync { parseResult in
            let result: Swift.Result<Podcast, PodcastLoadingError>
            do {
                switch parseResult {
                case .atom(let atom):
                    result = try .success(self.convert(atom: atom))
                case .rss(let rss):
                    result = try .success(self.convert(rss: rss))
                case .json(_): fatalError()
                case .failure(let e):
                    result = .failure(.feedParsingError(e))
                }
            } catch let e as PodcastLoadingError {
                result = .failure(e)
            } catch {
                fatalError()
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private func convert(atom: AtomFeed) throws -> Podcast {
        guard let name = atom.title else { throw PodcastLoadingError.feedMissingData("title")  }

        let author = atom.authors?.compactMap({ $0.name }).joined(separator: ", ") ?? ""

        guard let logoURL = atom.logo.flatMap(URL.init) else {
            throw PodcastLoadingError.feedMissingData("logo")
        }

        let description = atom.subtitle?.value ?? ""

        let p = Podcast()
        p.title = name
        p.author = author
        p.artworkURL = logoURL
        p.description = description
        p.primaryGenre = atom.categories?.first?.attributes?.label
        return p
    }

    private func convert(rss: RSSFeed) throws -> Podcast {
        guard let title = rss.title else { throw PodcastLoadingError.feedMissingData("title") }
        guard let author = rss.iTunes?.iTunesOwner?.name else {
            throw PodcastLoadingError.feedMissingData("itunes:owner name")
        }
        let description = rss.description ?? ""
        guard let logoURL = rss.iTunes?.iTunesImage?.attributes?.href.flatMap(URL.init) else {
            throw PodcastLoadingError.feedMissingData("itunes:image url")
        }

        let p = Podcast()
        p.title = title
        p.author = author
        p.artworkURL = logoURL
        p.description = description
        p.primaryGenre = rss.categories?.first?.value ?? rss.iTunes?.iTunesCategories?.first?.attributes?.text
        return p
    }
}
