import urllib.request
import re

movies = [
    (1, "The_Super_Mario_Bros._Movie"),
    (2, "Project_Hail_Mary_(film)"),
    (3, "Scream_VI"), 
    (4, "Greenland_(film)"),
    (5, "The_Drama_(film)"),
    (6, "Hoppers_(film)"),
    (7, "Under_the_Tuscan_Sun_(film)") 
]

for m_id, title in movies:
    url = f"https://en.wikipedia.org/wiki/{title}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        html = response.read().decode('utf-8')
        
        match = re.search(r'class="infobox-image".*?src="//([^"]+)"', html, re.DOTALL)
        if match:
            img_url = "https://" + match.group(1)
            img_url = re.sub(r'/thumb(/.*)/[^/]+$', r'\1', img_url)
            print(f"Found {title}: {img_url}")
            
            img_req = urllib.request.Request(img_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(img_req) as img_resp, open(f"../assets/poster{m_id}.jpg", 'wb') as f:
                f.write(img_resp.read())
        else:
            print(f"No image found for {title}")
    except Exception as e:
        print(f"Error for {title}: {e}")
