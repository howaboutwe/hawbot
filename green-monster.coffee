# Description:
#   How's our friendly green monster doing? 
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot green monster - check jenkins green monster

objects = [
  'grape',
  'basketball',
  'globe',
  'goblin',
  'hair',
  'animated gif'
]

module.exports = (robot) ->

  robot.respond /green monster/i, (msg) ->
    msg.http("http://jenkins.hawops.net/plugin/the-green-monster/status/api/json")
      .get() (err, res, body) ->
        try
          green = JSON.parse(body)['ok']
          object = msg.random objects
          imageMe msg, "green #{object}", (url) ->
            msg.send url
        catch error
          imageMe msg, "red #{object}", (url) ->
            msg.send url

imageMe = (msg, query, animated, faces, cb) ->
  cb = animated if typeof animated == 'function'
  cb = faces if typeof faces == 'function'
  q = v: '1.0', rsz: '8', q: query, safe: 'active'
  q.imgtype = 'animated' if typeof animated is 'boolean' and animated is true
  q.imgtype = 'face' if typeof faces is 'boolean' and faces is true
  msg.http('http://ajax.googleapis.com/ajax/services/search/images')
    .query(q)
    .get() (err, res, body) ->
      images = JSON.parse(body)
      images = images.responseData?.results
      if images?.length > 0
        image  = msg.random images
        cb "#{image.unescapedUrl}#.png"

