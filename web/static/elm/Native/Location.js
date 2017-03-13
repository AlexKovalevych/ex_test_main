var _user$project$Native_Location = function() {
    function getLocation()
    {
        var location = document.location;

        return {
            href: location.href,
            host: location.host,
            hostname: location.hostname,
            protocol: location.protocol,
            origin: location.origin,
            port_: location.port,
            pathname: location.pathname,
            search: location.search,
            hash: location.hash,
            username: location.username,
            password: location.password
        };
    }

    return {
        getLocation: getLocation
    };
}();
