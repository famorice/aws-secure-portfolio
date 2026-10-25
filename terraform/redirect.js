function handler(event) {
    var request = event.request;

    return {
        statusCode: 302,
        statusDescription: "Found",
        headers: {
            location: {
                value: "https://it.famory-sissoko.com" + request.uri
            },
            "cache-control": {
                value: "no-store"
            }
        }
    };
}