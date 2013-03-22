fs = require("fs")

csv = require("fast-csv")
async = require("async")
mkdirp = require("mkdirp")
#path = require("path")
path = require("path-extra")


#PATH SETUP
homeDir = path.homedir()
csvFile = process.cwd() + '/fixtures/ccpd_table_synonyms.csv'
baseDir = path.join homeDir, "Projects", "ccpd-platform"
inDir = path.join baseDir, "_com"
outDir = path.join baseDir, "_com"
mkdirp.sync outDir

walk = (dir, done) ->
  results = []
  fs.readdir dir, (err, list) ->
    return done(err)  if err
    i = 0
    (next = ->
      file = list[i++]
      return done(null, results) unless file

      #file = dir + "/" + file
      
      file = path.join dir,file
      #console.log("FILE: " + file)

      fs.stat file, (err, stat) ->
        if stat and stat.isDirectory()
          walk file, (err, res) ->
            results = results.concat(res)
            next()
            return
        else
          newPath = file.replace(inDir,'')
          results.push newPath
          next()
        return

    )()
    return
  return


console.log "[CONFIG] " + inDir
console.log "[CONFIG] " + outDir


files = []

tables = []

get_table_names = (callback) ->
  cb = callback
  csv(csvFile,
    headers: true
  ).on("data", (data) ->
    tables.push data
    return
  ).on("end", ->
    cb null, "one"
    return
  ).parse()
  return

get_files_list = (callback) ->
  cb = callback
  walk inDir, (err, results) -> 
    if (err) then return console.log err

    files = results
    cb(null,"two")
    return

  return


loop_files = (callback) ->
  cb = callback
  async.eachLimit files, 5, process_file, (err) ->
    #if !err then cb(null)
    return
  return

# if any of the saves produced an error, err would equal that error
process_file = (file,callback) ->
  console.log("[" + path.basename(file) + "] Processing...");
  cb_main = callback
  inFile = path.join inDir,file
  outFile = path.join outDir,file
  fs.readFile inFile, "utf8", (err, data) ->
    theData = data
    #return console.log(err) if err
    #console.log theData
    async.eachSeries tables, ((table, callback) ->
      console.log "[" + path.basename(file) + "] Replacing '" + table.old_name + "' with '" + table.new_name + "'"
      cb = callback
      regEx = new RegExp(table.old_name, "ig")
      finds = theData.match(regEx)
      theData = theData.replace(regEx, table.new_name)
      #console.log theData
      fileDir = path.dirname(outFile)
      
      mkdirp fileDir, (err) ->
        fs.writeFile outFile, theData, "utf8", ->
          cb null
          return
        return
      return
    ), (err) ->
      # if !err then cb_main(null)
      # console.log err
      cb_main()
      return
    return



async.series [get_table_names, get_files_list, loop_files]