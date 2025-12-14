# AI Optimization Guide

Use this guide to generate an optimized service configuration using an AI assistant (like ChatGPT, Claude, or Gemini).

## Instructions

1.  **Export** your current services to a JSON file (using `ManageServices.ps1` or the GUI).
2.  **Open** the JSON file and copy its entire content to your clipboard.
3.  **Paste** the prompt below into your AI chat, followed by your JSON data.
4.  **Save** the AI's response as a new JSON file (e.g., `ai-optimized.json`) in the `configs` directory.
5.  **Load & Restore** this new file using the GUI.

## AI Prompt

Copy and paste this into the chat:

***

I have a list of Windows 11 services exported in JSON format. Please analyze them and recommend which ones can be safely set to **Manual** or **Disabled** to optimize performance and reduce memory usage, while keeping the system stable for **[INSERT YOUR USE CASE: e.g., PC Gaming, Software Development, General Office Work]**.

Please follow these rules:
1.  **Safety First**: Do not disable critical system services (networking, user profile, security).
2.  **Format**: Output the result as a **valid JSON list** exactly matching the input format. Only include the services you recommend changing.
3.  **Explanation**: Briefly explain why you recommend disabling specific groups of services (e.g., "Disabled Xbox services as they are unused for office work").

Here is my current service list:

[PASTE YOUR JSON DATA HERE]
