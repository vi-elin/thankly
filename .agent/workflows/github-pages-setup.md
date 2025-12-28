---
description: How to set up GitHub Pages for Terms of Service and Privacy Policy
---

# GitHub Pages Setup for Legal Documents

## Prerequisites
- Your project must be in a GitHub repository
- You need push access to the repository

## Steps

### 1. Create a `docs` folder in your project root
```bash
mkdir docs
```

### 2. Create the HTML files
The HTML files for Privacy Policy and Terms of Service will be created in the `docs` folder.

### 3. Push to GitHub
```bash
git add docs/
git commit -m "Add Terms of Service and Privacy Policy pages"
git push origin main
```

### 4. Enable GitHub Pages
1. Go to your GitHub repository in a web browser
2. Click on **Settings** tab
3. Scroll down to **Pages** section (in the left sidebar under "Code and automation")
4. Under **Source**, select **Deploy from a branch**
5. Under **Branch**, select `main` and `/docs` folder
6. Click **Save**

### 5. Wait for deployment
- GitHub will build and deploy your site (usually takes 1-2 minutes)
- Your pages will be available at:
  - `https://[your-username].github.io/gratitude_app/privacy-policy.html`
  - `https://[your-username].github.io/gratitude_app/terms-of-service.html`

### 6. Verify the URLs
- Click on the provided URL in the GitHub Pages section
- Test both privacy-policy.html and terms-of-service.html

### 7. Update your app
Add these URLs to your Flutter app's settings screen or wherever you reference legal documents.

## Custom Domain (Optional)
If you want to use a custom domain:
1. Add a `CNAME` file in the `docs` folder with your domain name
2. Configure DNS settings with your domain provider
3. Update the custom domain in GitHub Pages settings

## Notes
- Changes to HTML files will automatically redeploy when pushed to GitHub
- It may take a few minutes for changes to appear
- GitHub Pages is free for public repositories
