module PostsHelper

  def on_your_posts_page?
    action_name == 'your_posts'
  end
end
