library(stringr)
library(tools)

#' Insert an image from a url
#' @description This function is supposed to be used in R code chunks or inline R code expressions.
#' - If the output is not pdf, then this function works the samge as `knitr::include_graphics()`.
#' - If the output is pdf, then the image will be downloaded to the img_dir directory and inserted.
#' - If the image is in gif format, then it will be converted into png before inserted into pdf.
#' @param img_url The url of the image
#' @param img_dir The path of the local image directory
#'
#' @return The same as the ` knitr::include_graphics()` function
#' @export
include_image <- function(img_url, img_dir = 'images') {
  file_name <- basename(img_url)
  img_local <- file.path(img_dir, file_name)
  ifelse(!dir.exists(img_dir), dir.create(img_dir), FALSE)

  while(file.exists(img_local)) {
    print (img_local)
    name = paste(file_path_sans_ext(img_local), "1", sep="_")
    ext = file_ext(img_local)
    img_local = paste(name, ext, sep=".")
  }

  download.file(img_url, img_local, mode = 'wb')
  if(grepl('\\.gif$', img_local)) {
    giffile <- magick::image_read(img_local)
    img_new <- gsub('\\.gif$', '\\.png', img_local)
    magick::image_write(magick::image_convert(giffile, format = 'png'), img_new)
    img_local <- img_new
  }

  img_local
}

#' Update the image URLs in RMarkdown files
#' @description This function is used in the build script of Steem Guide
#' @param img_dir The path of the local image directory
#'
#' @return null
#' @export
update_image_urls <- function(img_dir = 'images') {
  # iterate RMarkdown files
  files <- list.files(".", ".*\\.Rmd$")
  for (f in files) {
    prefix <- str_replace(f, "\\.Rmd$", "")
    prefix <- paste("chapter_", prefix, sep="")
    # dirty solution: ingore the chapter that introduces MD syntax
    # to skip the case that the image url is in a MD code block
    if (f != "04_0.Rmd" && f != "steemh.Rmd" ) {
      # read ![.*](image url) or <img ... src="image url" ... />
      img_url_regex = "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)\\.(jpg|jpeg|png|gif|svg)"
      # img_url_regex <- "(https?:\\/\\/.*\\.(?:png|jpe?g|gif|svg))"
      img_block_regex <- paste("!\\[.*\\]\\(", img_url_regex, "\\)", sep="")
      img_tags_regex <- paste("<img[^>]+src=\"", img_url_regex, "\"", sep="")
      img_regex <- paste(img_block_regex, img_tags_regex, sep="|")

      md <- readLines(f)
      img_statements <- str_extract_all(md, regex(img_regex, ignore_case = TRUE))
      img_urls <- str_extract_all(img_statements, regex(img_url_regex, ignore_case = TRUE))

      # replace img urls with local image path
      has_modified = FALSE
      for (i in 1:length(md)) {
        urls <- img_urls[[i]]
        if (length(urls) > 0) {
          for (j in 1:length(urls)) {
            url <- urls[[j]]
            folder <- file.path(img_dir, prefix)
            path <- include_image(url, folder)
            md[[i]] <- str_replace(md[[i]], url, path)
            print (md[[i]])
          }
          has_modified = TRUE
        }
      }

      # write back the modified RMarkdown text
      if (has_modified) {
        writeLines(md, f)
      }
    }
  }
}

update_image_urls(img_dir = "images")



