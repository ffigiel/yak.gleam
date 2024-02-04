export function preventDefaultOnEvent(e) {
    e.preventDefault()
}

export function apiRequest(path, body) {
    console.log(path, body)
    return fetch("https://api.yak.localhost:3000" + path, {
        method: "POST",
        credentials: 'include',
        body,
    })
}
