require 'vk/post'

require 'delegate'

module Vk
  class Post
    class Wall
      extend ActiveSupport::Memoizable

      attr_accessor :uid, :count, :posts

      def initialize(uid, count, posts)
        self.uid, self.count, self.posts = uid, count, posts
      end

      def user
        Vk::User.find(uid)
      end
      memoize :user

      def [](index)
        raise "Post #{index} is not exist"  if index > count + 1
        load_posts_to(index)                if index >= loaded_posts
        if post = posts[index]
          Vk::Post.find(Vk::Post.id_for(post), data: post)
        end
      end

      def first; self[0]; end

      def each(&block)
        load_all_posts
        0.upto(count) do |index|
          block.call(self[index])
        end
      end

      def method_missing(method, *args)
        if posts.respond_to?(method)
          posts.send(method, *args)
        else
          super
        end
      end

      protected

      def load_post(index)
        count, *new_posts = Vk::Base.loader.get_wall(uid, offset: loaded_posts, count: index - loaded_posts + 1)
        self.posts += new_posts
        posts[index]
      end

      def load_posts_to(count)
        load_post(loaded_posts + 100) while loaded_posts < count
      end

      def load_all_posts
        load_posts_to(count)
      end

      def loaded_posts
        posts.size
      end
    end
  end
end
