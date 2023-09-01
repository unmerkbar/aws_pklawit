import requests
import base64

wordpress_user = "wp_admin"
wordpress_password = "YG1U87Jl1gOdofbFLGx1cEhj"
wordpress_credentials = "%s:%s" % (wordpress_user, wordpress_password)
wordpress_token = base64.b64encode(wordpress_credentials.encode())
wordpress_header = {'Authorization': 'Basic ' + wordpress_token.decode('utf-8')}

api_url = 'https://35.180.179.247/index.php/wp-json/wp/v2/posts'

# print("wordpress_header: %s" % wordpress_header)

def read_wordpress_posts():
  response = requests.get(api_url, verify=False)
  response_json = response.json()
  print(response_json)

def create_wordpress_post():
  data = {
    'title' : 'Post created with WP API',
    'status': 'publish',
    'slug' : 'API published post',
    'content': 'This post has been created with REST API'
  }
  response = requests.post(api_url,headers=wordpress_header, json=data, verify=False)
  print(response)

# Main part

#read_wordpress_posts()

create_wordpress_post()
