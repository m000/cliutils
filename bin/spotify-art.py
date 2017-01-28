#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
    See: https://developer.spotify.com/web-api/search-item/
'''

import requests
import argparse
import json
import shutil

API_BASE_URL = 'https://api.spotify.com/v1'
API_SEARCH_URL = '%s/search' % (API_BASE_URL)
API_SEARCH_TYPES = ['album', 'artist', 'playlist', 'track',]
API_SEARCH_DEFAULT_TYPE = 'album'

def make_image_name(item, n):
    if item['type'] == 'album':
        fmt = '{artist} - {name}.jpg'
        if len(item['artists']) > 1:
            artist = 'Various'
        else:
            artist = item['artists'][0]['name']
        kwargs = {
            'name': it['name'],
            'artist': artist,
            'n': n,
        }
        img_name = fmt.format(**kwargs)
    elif item['type'] == 'artist':
        fmt = '{name}_{n:02d}.jpg'
        kwargs = {
            'name': it['name'],
            'n': n,
        }
        img_name = fmt.format(**kwargs)
    elif item['type'] == 'playlist':
        fmt = 'pl_{owner}_{name}.jpg'
        kwargs = {
            'name': it['name'],
            'owner': it['owner']['id'],
            'n': n,
        }
        img_name = fmt.format(**kwargs).lower()
    elif item['type'] == 'track':
        fmt = 't{n:02d} - {artist} - {name}.jpg'
        if len(item['artists']) > 1:
            artist = 'Various'
        else:
            artist = item['artists'][0]['name']
        kwargs = {
            'name': it['name'],
            'artist': artist,
            'n': n,
        }
        img_name = fmt.format(**kwargs)
    else:
        assert False, 'Unknown item type "%s".' % (item['type'])

    return img_name.replace('/', '+')


def retrieve_image(url, name):
    r = requests.get(url, stream=True)
    r.raise_for_status()
    with open(name, 'wb') as f:
        # gzip/deflate compression handling
        r.raw.decode_content = True
        shutil.copyfileobj(r.raw, f)
        f.close()
        r.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="""Spotify artwork downloader.
    """)
    parser.add_argument("-t", "--type",
        action="append", dest="search_type",
        choices=API_SEARCH_TYPES,
        default=[],
        help="specify search type",
    )
    parser.add_argument("-n",
        action="store", dest="search_limit",
        type=lambda v: min(50, max(1, int(v))),
        default=5, metavar='LIMIT',
        help="number of results to retrieve (max 50)",
    )
    parser.add_argument("-o",
        action="store", dest="search_offset",
        type=lambda v: min(100000, max(0, int(v))),
        default=0, metavar='OFFSET',
        help="offset of the first result to be retrieved",
    )
    parser.add_argument('search_query', metavar='QUERY', help='search query')

    args = parser.parse_args()
    args.search_type = sorted(set(args.search_type))

    params = {
        'q': args.search_query,
        'type': ','.join(args.search_type) if args.search_type else API_SEARCH_DEFAULT_TYPE,
        'limit': args.search_limit,
        'offset': args.search_offset,
    }
    r = requests.get(API_SEARCH_URL, params=params)
    response = r.json()

    #print(json.dumps(response))
    #assert False, 'stop'

    for k, v in response.items():
        # strip trailing 's' from k and check the type
        result_type = k[:-1]
        assert result_type in API_SEARCH_TYPES, 'Query returned unknown result type "%s".' % (k)
        assert 'items' in v, 'No items in returned result for type "%s".' % (k)

        for n, it in enumerate(v['items']):
            if 'images' in it:
                images = it['images']
            elif 'album' in it and 'images' in it['album']:
                images = it['album']['images']
            else:
                continue

            # find largest image
            img_max = (-1, -1)
            for i, img in enumerate(images):
                w = img['width'] or 0
                h = img['height'] or 0
                if (w*h) > img_max[1]:
                    img_max = (i, w*h)
            if img_max == (-1, -1): continue

            # get url and pixel count for largest image
            img_max = (images[img_max[0]]['url'], img_max[1])

            # make an image name
            img_name = make_image_name(it, n)

            retrieve_image(img_max[0], img_name)

            print(img_name, img_max[0])

# vim: ts=4 sts=4 sw=4 et noai :
