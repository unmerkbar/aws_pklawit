import requests
import base64
import sys

wordpress_user = "wp_admin"
wordpress_password = "NuYm4t13PvEuFaebpxaBXlFL"
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

# total arguments
n = len(sys.argv)
print("Number of arguments passed:", n)
 
# Arguments passed
print("\nName of Python script:", sys.argv[0])
 
print("\nArguments passed:", end = " ")
for i in range(1, n):
    print(sys.argv[i], end = " ")


#read_wordpress_posts()

#create_wordpress_post()
