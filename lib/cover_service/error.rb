module CoverService
  module Error
    class StandardError < StandardError
      def http_status
        500
      end
    end

    class NotFound < StandardError
      def http_status
        404
      end
    end

    class NotAllowed < StandardError
      def http_status
        401
      end
    end

    class BadRequest < StandardError
      def http_status
        400
      end
    end

    class UnprocessableContent < StandardError
      def http_status
        422
      end
    end

    class InternalServerError < StandardError
      def http_status
        500
      end
    end
    

  end
end