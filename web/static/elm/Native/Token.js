var _user$project$Native_Token = function() {
    function getToken()
    {
      return document.querySelector('meta[name="guardian_token"]').getAttribute('content');
    }

    return {
        getToken: getToken
    };
}();
